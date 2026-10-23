package main

import (
	"log"

	"personal-notes-backend/database"
	"personal-notes-backend/routes"
)

func main() {
	// 初始化数据库
	database.InitDB()
	db := database.GetDB()

	// 配置路由
	r := routes.SetupRouter(db)

	// 启动服务
	log.Println("Personal Notes API Server starting on :8080")
	if err := r.Run(":8080"); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}
