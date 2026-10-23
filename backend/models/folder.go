package models

import "time"

// Folder 目录模型
type Folder struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	UserID    uint      `gorm:"index;not null" json:"user_id"`
	Name      string    `gorm:"size:100;not null" json:"name"`
	CreatedAt time.Time `json:"created_at"`
}

// TableName 指定表名
func (Folder) TableName() string {
	return "folders"
}
