package models

import (
	"time"
)

// User 用户模型
type User struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Username  string    `gorm:"size:50;uniqueIndex;not null" json:"username"`
	Phone     *string   `gorm:"size:20;uniqueIndex" json:"phone,omitempty"`
	Email     *string   `gorm:"size:100;uniqueIndex" json:"email,omitempty"`
	Password  string    `gorm:"size:255;not null" json:"-"` // 不返回给前端
	Nickname  string    `gorm:"size:50" json:"nickname"`
	AvatarURL string    `gorm:"size:500" json:"avatar_url"`
	Birthday  *time.Time `json:"birthday,omitempty"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// UserResponse 用户响应（脱敏）
type UserResponse struct {
	ID        uint       `json:"id"`
	Username  string     `json:"username"`
	Phone     string     `json:"phone"`      // 脱敏后的手机号
	Email     string     `json:"email"`
	Nickname  string     `json:"nickname"`
	AvatarURL string     `json:"avatar_url"`
	Birthday  *time.Time `json:"birthday,omitempty"`
}

// ToResponse 转换为响应结构（手机号脱敏）
func (u *User) ToResponse() UserResponse {
	phone := ""
	if u.Phone != nil {
		phone = maskPhone(*u.Phone)
	}
	email := ""
	if u.Email != nil {
		email = *u.Email
	}
	return UserResponse{
		ID:        u.ID,
		Username:  u.Username,
		Phone:     phone,
		Email:     email,
		Nickname:  u.Nickname,
		AvatarURL: u.AvatarURL,
		Birthday:  u.Birthday,
	}
}

// maskPhone 手机号脱敏（138****8000）
func maskPhone(phone string) string {
	if len(phone) != 11 {
		return phone
	}
	return phone[:3] + "****" + phone[7:]
}

// TableName 指定表名
func (User) TableName() string {
	return "users"
}
