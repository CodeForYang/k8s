
import os
import redis
from flask import Flask

app = Flask(__name__)

redis_host = os.getenv("REDIS_HOST", "redis")
redis_port = int(os.getenv("REDIS_PORT", "6379"))
app_name = os.getenv("APP_NAME", "K8s Demo")
bg_color = os.getenv("BG_COLOR", "#f0f0f0")

r = redis.Redis(host=redis_host, port=redis_port, decode_responses=True)

@app.route("/")
def hello():
    try:
        count = r.incr("visits")
        return f"""
        <html>
        <body style="background:{bg_color}; 
                     font-family:sans-serif; 
                     display:flex; 
                     justify-content:center; 
                     align-items:center; 
                     height:100vh;">
          <div style="text-align:center; background:white; padding:40px; border-radius:10px;
                      box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
            <h1 style="color:#333;">{app_name}</h1>
            <p style="font-size:48px; margin:20px 0; color:#4CAF50;">{count}</p>
            <p style="color:#666;">页面访问次数</p>
          </div>
        </body>
        </html>
        """
    except Exception as e:
        return f"<h1>Redis 连接失败: {e}</h1>", 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)