package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
	"personal-notes-backend/models"
)

// NoteHandler 笔记相关处理器
type NoteHandler struct {
	DB *gorm.DB
}

// NewNoteHandler 创建笔记处理器
func NewNoteHandler(db *gorm.DB) *NoteHandler {
	return &NoteHandler{DB: db}
}

// ListNotes 获取笔记列表（支持分页和按文件夹筛选）
func (h *NoteHandler) ListNotes(c *gin.Context) {
	userID, _ := c.Get("user_id")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	folderIDStr := c.Query("folder_id")

	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}
	offset := (page - 1) * pageSize

	query := h.DB.Where("user_id = ?", userID)
	if folderIDStr != "" {
		folderID, err := strconv.ParseUint(folderIDStr, 10, 64)
		if err == nil {
			query = query.Where("folder_id = ?", folderID)
		}
	}

	var total int64
	query.Model(&models.Note{}).Count(&total)

	var notes []models.Note
	if err := query.Order("updated_at DESC").Offset(offset).Limit(pageSize).Find(&notes).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "查询笔记失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "查询成功",
		"data": gin.H{
			"notes":     notes,
			"total":     total,
			"page":      page,
			"page_size": pageSize,
		},
	})
}

// GetNote 获取单个笔记详情
func (h *NoteHandler) GetNote(c *gin.Context) {
	userID, _ := c.Get("user_id")
	noteID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "无效的笔记ID"})
		return
	}

	var note models.Note
	if err := h.DB.Where("id = ? AND user_id = ?", noteID, userID).First(&note).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"code": 404, "message": "笔记不存在"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "查询失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "查询成功",
		"data":    note,
	})
}

// CreateNote 创建笔记
func (h *NoteHandler) CreateNote(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var req struct {
		Title    string `json:"title" binding:"required,max=200"`
		Content  string `json:"content"`
		FolderID *uint  `json:"folder_id"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "请求参数错误: " + err.Error()})
		return
	}

	// 如果指定了文件夹，验证文件夹是否存在且属于当前用户
	if req.FolderID != nil {
		var folder models.Folder
		if err := h.DB.Where("id = ? AND user_id = ?", *req.FolderID, userID).First(&folder).Error; err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "指定的文件夹不存在"})
			return
		}
	}

	note := models.Note{
		UserID:   userID.(uint),
		Title:    req.Title,
		Content:  req.Content,
		FolderID: req.FolderID,
	}

	if err := h.DB.Create(&note).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "创建笔记失败"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"code":    201,
		"message": "创建成功",
		"data":    note,
	})
}

// UpdateNote 更新笔记
func (h *NoteHandler) UpdateNote(c *gin.Context) {
	userID, _ := c.Get("user_id")
	noteID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "无效的笔记ID"})
		return
	}

	var req struct {
		Title    string `json:"title" binding:"omitempty,max=200"`
		Content  *string `json:"content"`
		FolderID *uint  `json:"folder_id"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "请求参数错误: " + err.Error()})
		return
	}

	// 验证笔记存在且属于当前用户
	var note models.Note
	if err := h.DB.Where("id = ? AND user_id = ?", noteID, userID).First(&note).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": 404, "message": "笔记不存在"})
		return
	}

	// 如果指定了文件夹，验证文件夹存在
	if req.FolderID != nil {
		var folder models.Folder
		if err := h.DB.Where("id = ? AND user_id = ?", *req.FolderID, userID).First(&folder).Error; err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "指定的文件夹不存在"})
			return
		}
	}

	updates := map[string]interface{}{}
	if req.Title != "" {
		updates["title"] = req.Title
	}
	if req.Content != nil {
		updates["content"] = *req.Content
	}
	if req.FolderID != nil {
		updates["folder_id"] = *req.FolderID
	}

	if len(updates) > 0 {
		h.DB.Model(&note).Updates(updates)
	}

	// 重新查询获取更新后的数据
	h.DB.Where("id = ?", noteID).First(&note)

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "更新成功",
		"data":    note,
	})
}

// DeleteNote 删除笔记
func (h *NoteHandler) DeleteNote(c *gin.Context) {
	userID, _ := c.Get("user_id")
	noteID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "无效的笔记ID"})
		return
	}

	var note models.Note
	if err := h.DB.Where("id = ? AND user_id = ?", noteID, userID).First(&note).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": 404, "message": "笔记不存在"})
		return
	}

	if err := h.DB.Delete(&note).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "删除失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "删除成功",
		"data":    nil,
	})
}
