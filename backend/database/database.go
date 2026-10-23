package database

import (
	"log"

	"github.com/glebarez/sqlite"
	"gorm.io/gorm"
	"personal-notes-backend/models"
)

var DB *gorm.DB

// InitDB 初始化数据库
func InitDB() {
	var err error
	DB, err = gorm.Open(sqlite.Open("notes.db"), &gorm.Config{})
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	// 自动迁移所有表
	err = DB.AutoMigrate(
		&models.User{},
		&models.Note{},
		&models.Folder{},
		&models.Avatar{},
		&models.VerificationCode{},
	)
	if err != nil {
		log.Fatal("Failed to migrate database:", err)
	}

	log.Println("Database connected and migrated successfully")
}

// GetDB 获取数据库实例
func GetDB() *gorm.DB {
	return DB
}
