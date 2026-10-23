package utils

import (
	"errors"
	"regexp"

	"golang.org/x/crypto/bcrypt"
)

// 密码必须是6位纯数字
var passwordRegex = regexp.MustCompile(`^\d{6}$`)

// ValidatePassword 验证密码是否为6位数字
func ValidatePassword(password string) error {
	if !passwordRegex.MatchString(password) {
		return errors.New("密码必须为6位数字")
	}
	return nil
}

// HashPassword 对密码进行bcrypt加密
func HashPassword(password string) (string, error) {
	if err := ValidatePassword(password); err != nil {
		return "", err
	}
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	return string(bytes), err
}

// CheckPassword 校验密码
func CheckPassword(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}
