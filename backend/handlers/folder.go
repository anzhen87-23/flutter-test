package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
	"personal-notes-backend/models"
)

// FolderHandler 文件夹相关处理器
type FolderHandler struct {
	DB *gorm.DB
}

// NewFolderHandler 创建文件夹处理器
func NewFolderHandler(db *gorm.DB) *FolderHandler {
	return &FolderHandler{DB: db}
}

// ListFolders 获取当前用户的所有文件夹
func (h *FolderHandler) ListFolders(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var folders []models.Folder
	if err := h.DB.Where("user_id = ?", userID).Order("created_at DESC").Find(&folders).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "查询文件夹失败"})
		return
	}

	// 为每个文件夹统计笔记数量
	type FolderWithCount struct {
		models.Folder
		NoteCount int64 `json:"note_count"`
	}
	var result []FolderWithCount
	for _, folder := range folders {
		var count int64
		h.DB.Model(&models.Note{}).Where("folder_id = ?", folder.ID).Count(&count)
		result = append(result, FolderWithCount{
			Folder:    folder,
			NoteCount: count,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "查询成功",
		"data":    result,
	})
}

// GetFolder 获取单个文件夹
func (h *FolderHandler) GetFolder(c *gin.Context) {
	userID, _ := c.Get("user_id")
	folderID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "无效的文件夹ID"})
		return
	}

	var folder models.Folder
	if err := h.DB.Where("id = ? AND user_id = ?", folderID, userID).First(&folder).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"code": 404, "message": "文件夹不存在"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "查询失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "查询成功",
		"data":    folder,
	})
}

// CreateFolder 创建文件夹
func (h *FolderHandler) CreateFolder(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var req struct {
		Name string `json:"name" binding:"required,max=100"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "请求参数错误: " + err.Error()})
		return
	}

	// 检查同名文件夹
	var count int64
	h.DB.Model(&models.Folder{}).Where("user_id = ? AND name = ?", userID, req.Name).Count(&count)
	if count > 0 {
		c.JSON(http.StatusConflict, gin.H{"code": 409, "message": "同名文件夹已存在"})
		return
	}

	folder := models.Folder{
		UserID: userID.(uint),
		Name:   req.Name,
	}

	if err := h.DB.Create(&folder).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "创建文件夹失败"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"code":    201,
		"message": "创建成功",
		"data":    folder,
	})
}

// UpdateFolder 更新文件夹
func (h *FolderHandler) UpdateFolder(c *gin.Context) {
	userID, _ := c.Get("user_id")
	folderID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "无效的文件夹ID"})
		return
	}

	var req struct {
		Name string `json:"name" binding:"required,max=100"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "请求参数错误: " + err.Error()})
		return
	}

	// 验证文件夹存在
	var folder models.Folder
	if err := h.DB.Where("id = ? AND user_id = ?", folderID, userID).First(&folder).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": 404, "message": "文件夹不存在"})
		return
	}

	// 检查新名称是否与其他文件夹重复
	var count int64
	h.DB.Model(&models.Folder{}).Where("user_id = ? AND name = ? AND id != ?", userID, req.Name, folderID).Count(&count)
	if count > 0 {
		c.JSON(http.StatusConflict, gin.H{"code": 409, "message": "同名文件夹已存在"})
		return
	}

	h.DB.Model(&folder).Update("name", req.Name)

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "更新成功",
		"data":    folder,
	})
}

// DeleteFolder 删除文件夹
func (h *FolderHandler) DeleteFolder(c *gin.Context) {
	userID, _ := c.Get("user_id")
	folderID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "无效的文件夹ID"})
		return
	}

	var folder models.Folder
	if err := h.DB.Where("id = ? AND user_id = ?", folderID, userID).First(&folder).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": 404, "message": "文件夹不存在"})
		return
	}

	// 将文件夹内的笔记移动到"未分类"（folder_id = NULL）
	h.DB.Model(&models.Note{}).Where("folder_id = ?", folderID).Update("folder_id", nil)

	if err := h.DB.Delete(&folder).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "删除失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "删除成功",
		"data":    nil,
	})
}
