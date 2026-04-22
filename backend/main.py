# -*- coding: utf-8 -*-
"""
FastAPI 主入口
挂载 CORS、API 路由、前端静态目录；`/` 返回前端，`/api/*` 走接口。
启动时会调用 backend/api/routes.py 中的 router 路由，
"""
import os
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware

from .config import BASE_DIR
from .api.routes import router

app = FastAPI(
    title="SQL 知识图谱系统",
    description="从 SQL 脚本解析表与关系，构建并可视化知识图谱",
    version="1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router)

# 前端目录（必须放在 mount 之前定义路由，否则会被 StaticFiles 覆盖）
frontend_path = os.path.join(BASE_DIR, "frontend")


@app.get("/health")
def health():
    """健康检查，必须在 mount 之前定义"""
    return {"status": "ok"}


@app.get("/")
def index():
    """显式返回前端首页，避免依赖 StaticFiles 对 / 的处理"""
    index_file = os.path.join(frontend_path, "index.html")
    if os.path.isfile(index_file):
        return FileResponse(index_file, media_type="text/html; charset=utf-8")
    return {"message": "frontend not found", "path": frontend_path}


# 静态资源（css/js）最后挂载
if os.path.isdir(frontend_path):
    app.mount("/", StaticFiles(directory=frontend_path, html=True), name="frontend")
