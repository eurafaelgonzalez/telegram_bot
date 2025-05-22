import os
import time
import sqlite3
import logging
import requests
from dotenv import load_dotenv
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import (
    Application,
    CommandHandler,
    MessageHandler,
    CallbackQueryHandler,
    ContextTypes,
    filters,
)

# Configurar logging em DEBUG
logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s", level=logging.DEBUG
)
logger = logging.getLogger(__name__)

# Carregar variáveis do .env
load_dotenv()
BOT_TOKEN = os.getenv("BOT_TOKEN")
PAGSEGURO_EMAIL = "rafaelgoncalvessantos2020@gmail.com"
PAGSEGURO_TOKEN = "6F34E887A0A440E6944776FD7688ACFF"
PHOTO_PRICE = 25.0

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    logger.debug(f"Recebido /start do usuário {update.effective_user.id}")
    await update.message.reply_text(
        "Oi! Bem-vindo ao bot de fotos! 📸 Envie uma foto facial pra começar."
    )
    logger.info(f"Mensagem de boas-vindas enviada ao usuário {update.effective_user.id}")

async def handle_photo(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_id = update.effective_user.id
    logger.debug(f"Foto recebida do usuário {user_id}")
    photo = update.message.photo[-1]
    file = await photo.get_file()
    file_path = f"photos/{user_id}_{int(time.time())}.jpg"
    os.makedirs(os.path.dirname(file_path), exist_ok=True)
    await file.download_to_drive(file_path)
    keyboard = [
        [
            InlineKeyboardButton("FOTO1", callback_data="FOTO1"),
            InlineKeyboardButton("FOTO2", callback_data="FOTO2"),
        ]
    ]
    reply_markup = InlineKeyboardMarkup(keyboard)
    await update.message.reply_text("Foto recebida! Escolha uma opção:", reply_markup=reply_markup)
    logger.info(f"Opções enviadas ao usuário {user_id}")

async def choose_option(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()
    user_id = query.from_user.id
    option = query.data
    logger.debug(f"Usuário {user_id} escolheu {option}")
    payload = {
        "reference_id": f"order_{user_id}_{int(time.time())}",
        "customer": {
            "name": "Teste",
            "email": "teste@pagseguro.com.br",
            "tax_id": "98765432100",
            "phones": [{"country": "55", "area": "11", "number": "999999999", "type": "MOBILE"}]
        },
        "items": [{"name": f"Foto {option}", "quantity": 1, "unit_amount": int(PHOTO_PRICE * 100)}],
        "qr_codes": [{"amount": {"value": int(PHOTO_PRICE * 100)}, "expiration_date": time.strftime("%Y-%m-%dT%H:%M:%S-03:00", time.localtime(time.time() + 3600))}],
        "notification_urls": ["https://example.com/notify"]
    }
    try:
        response = requests.post(
            "https://sandbox.api.pagseguro.com/orders",
            headers={
                "Authorization": f"Bearer {PAGSEGURO_TOKEN}",
                "Content-Type": "application/json",
                "x-api-version": "4.0",
                "x-sandbox-token": PAGSEGURO_TOKEN
            },
            json=payload
        )
        response.raise_for_status()
        data = response.json()
        qr_code = data["qr_codes"][0]["text"]
        order_id = data["id"]
        with sqlite3.connect("users.db") as conn:
            conn.execute("INSERT INTO orders (user_id, option, order_id, status) VALUES (?, ?, ?, ?)",
                        (user_id, option, order_id, "PENDING"))
            conn.commit()
        await query.message.reply_text(
            f"Você escolheu {option}! Pague R$25.00 via PIX escaneando este QR code.\n\n"
            f"Chave PIX (copia e cola):\n{qr_code}\n\n"
            f"Aguarde a confirmação do pagamento (até 5 minutos). Quando confirmado, você recebe a foto! 😊"
        )
        logger.info(f"Cobrança PIX criada para usuário {user_id}, order_id: {order_id}")
        if context.job_queue:
            context.job_queue.run_repeating(
                check_payment_status, interval=10, first=5, data={"user_id": user_id, "order_id": order_id, "option": option}
            )
        else:
            logger.error("Job queue não disponível!")
            await query.message.reply_text("Erro interno no bot. Tente novamente ou use /ajuda.")
    except requests.RequestException as e:
        logger.error(f"Erro ao criar cobrança PIX: {e}")
        await query.message.reply_text(f"Ops, erro ao gerar o PIX: {e}. Tenta de novo ou usa /ajuda.")

async def check_payment_status(context: ContextTypes.DEFAULT_TYPE):
    data = context.job.data
    user_id = data["user_id"]
    order_id = data["order_id"]
    option = data["option"]
    try:
        response = requests.get(
            f"https://sandbox.api.pagseguro.com/orders/{order_id}",
            headers={
                "Authorization": f"Bearer {PAGSEGURO_TOKEN}",
                "Content-Type": "application/json",
                "x-api-version": "4.0",
                "x-sandbox-token": PAGSEGURO_TOKEN
            }
        )
        response.raise_for_status()
        data = response.json()
        status = data.get("charges", [{}])[0].get("status")
        if status == "PAID":
            photo_path = "123456789.jpg" if option == "FOTO1" else "987654321.jpg"
            with sqlite3.connect("users.db") as conn:
                conn.execute("UPDATE orders SET status = ? WHERE order_id = ?", ("PAID", order_id))
                conn.commit()
            with open(photo_path, "rb") as photo:
                await context.bot.send_photo(
                    chat_id=user_id,
                    photo=photo,
                    caption=f"Aqui está sua {option}! 😊"
                )
            logger.info(f"Pagamento confirmado para usuário {user_id}, foto {option} enviada.")
            context.job.schedule_removal()
    except requests.RequestException as e:
        logger.error(f"Erro ao verificar pagamento {order_id}: {e}")

def init_db():
    with sqlite3.connect("users.db") as conn:
        conn.execute(
            "CREATE TABLE IF NOT EXISTS orders (user_id INTEGER, option TEXT, order_id TEXT, status TEXT)"
        )
        conn.commit()
    logger.info("Banco de dados inicializado.")

def main():
    if not BOT_TOKEN:
        logger.error("BOT_TOKEN não configurado!")
        return
    app = Application.builder().token(BOT_TOKEN).build()
    app.add_handler(CommandHandler("start", start))
    app.add_handler(MessageHandler(filters.PHOTO, handle_photo))
    app.add_handler(CallbackQueryHandler(choose_option))
    init_db()
    app.run_polling()

if __name__ == "__main__":
    main()