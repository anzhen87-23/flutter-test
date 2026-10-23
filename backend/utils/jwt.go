package utils

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

var jwtSecret = []byte("personal-notes-secret-key-2024")

// JWT claims 结构
type Claims struct {
	UserID uint `json:"user_id"`
	jwt.RegisteredClaims
}

// GenerateToken 生成JWT token
func GenerateToken(userID uint) (string, error) {
	expirationTime := time.Now().Add(7 * 24 * time.Hour) // 7天过期

	claims := &Claims{
		UserID: userID,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expirationTime),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			Issuer:    "personal-notes",
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(jwtSecret)
}

// ParseToken 解析JWT token
func ParseToken(tokenStr string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenStr, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		return jwtSecret, nil
	})

	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		return claims, nil
	}

	return nil, errors.New("invalid token")
}
