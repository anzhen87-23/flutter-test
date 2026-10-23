package models

import "time"

// Note 笔记模型
type Note struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	UserID    uint      `gorm:"index;not null" json:"user_id"`
	FolderID  *uint     `gorm:"index" json:"folder_id,omitempty"`
	Title     string    `gorm:"size:200;not null" json:"title"`
	Content   string    `gorm:"type:text" json:"content"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// TableName 指定表名
func (Note) TableName() string {
	return "notes"
}
