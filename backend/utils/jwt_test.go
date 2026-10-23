package utils

import (
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/stretchr/testify/assert"
)

func TestGenerateToken_And_ParseToken(t *testing.T) {
	userID := uint(42)
	tokenStr, err := GenerateToken(userID)
	assert.NoError(t, err)
	assert.NotEmpty(t, tokenStr)

	claims, err := ParseToken(tokenStr)
	assert.NoError(t, err)
	assert.Equal(t, userID, claims.UserID)
	assert.Equal(t, "personal-notes", claims.Issuer)
	assert.True(t, claims.ExpiresAt.After(time.Now()))
}

func TestParseToken_Invalid(t *testing.T) {
	_, err := ParseToken("invalid.token.string")
	assert.Error(t, err)

	_, err = ParseToken("")
	assert.Error(t, err)
}

func TestParseToken_Tampered(t *testing.T) {
	// 生成有效token后篡改
	tokenStr, _ := GenerateToken(1)
	tampered := tokenStr + "x"
	_, err := ParseToken(tampered)
	assert.Error(t, err)
}

func TestParseToken_Expired(t *testing.T) {
	// 创建一个已过期的token
	claims := &Claims{
		UserID: 1,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(-1 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now().Add(-2 * time.Hour)),
			Issuer:    "personal-notes",
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	expiredToken, _ := token.SignedString(jwtSecret)

	_, err := ParseToken(expiredToken)
	assert.Error(t, err)
}
