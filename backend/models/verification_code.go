package models

import "time"

// VerificationCode 验证码模型
type VerificationCode struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Target    string    `gorm:"size:100;not null;index" json:"target"` // 手机号或邮箱
	Code      string    `gorm:"size:10;not null" json:"-"`             // 验证码（不返回给前端）
	Type      string    `gorm:"size:20;not null" json:"type"`          // register/reset_password/verify_phone/verify_email
	ExpiresAt time.Time `gorm:"not null" json:"expires_at"`
	Used      bool      `gorm:"default:false" json:"used"`
	CreatedAt time.Time `json:"created_at"`
}

// TableName 指定表名
func (VerificationCode) TableName() string {
	return "verification_codes"
}
