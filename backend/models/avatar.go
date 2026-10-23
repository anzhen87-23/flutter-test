package models

import "time"

// Avatar 头像模型
type Avatar struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	UserID    uint      `gorm:"index;not null" json:"user_id"`
	FilePath  string    `gorm:"size:500;not null" json:"file_path"`
	FileSize  int64     `json:"file_size"`
	MimeType  string    `gorm:"size:50" json:"mime_type"`
	CreatedAt time.Time `json:"created_at"`
}

// TableName 指定表名
func (Avatar) TableName() string {
	return "avatars"
}
