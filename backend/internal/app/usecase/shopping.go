package usecase

import (
	"context"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/repository"
)

type ShoppingListUsecase struct {
	Lists repository.ShoppingListRepository
}

type ShoppingListUpdateInput struct {
	Title  *string
	Status *string
}

func (uc *ShoppingListUsecase) Create(ctx context.Context, userID, title string, status *string) (domain.ShoppingList, error) {
	title = normalizeString(title)
	if userID == "" || title == "" {
		return domain.ShoppingList{}, ErrMissingRequiredFields
	}

	list := domain.ShoppingList{
		UserID: userID,
		Title:  title,
	}
	if status != nil {
		parsed, ok := parseShoppingListStatus(*status)
		if !ok {
			return domain.ShoppingList{}, ErrInvalidStatus
		}
		list.Status = parsed
	}

	return uc.Lists.Create(ctx, list)
}

func (uc *ShoppingListUsecase) Update(ctx context.Context, userID, id string, input ShoppingListUpdateInput) (domain.ShoppingList, error) {
	if userID == "" || id == "" {
		return domain.ShoppingList{}, ErrMissingRequiredFields
	}
	list, err := uc.Lists.Get(ctx, userID, id)
	if err != nil {
		return domain.ShoppingList{}, err
	}

	if input.Title != nil {
		trimmed := normalizeString(*input.Title)
		if trimmed == "" {
			return domain.ShoppingList{}, ErrMissingRequiredFields
		}
		list.Title = trimmed
	}
	if input.Status != nil {
		parsed, ok := parseShoppingListStatus(*input.Status)
		if !ok {
			return domain.ShoppingList{}, ErrInvalidStatus
		}
		list.Status = parsed
	}

	return uc.Lists.Update(ctx, list)
}

func (uc *ShoppingListUsecase) Delete(ctx context.Context, userID, id string) error {
	if userID == "" || id == "" {
		return ErrMissingRequiredFields
	}
	return uc.Lists.Delete(ctx, userID, id)
}

func (uc *ShoppingListUsecase) Get(ctx context.Context, userID, id string) (domain.ShoppingList, error) {
	if userID == "" || id == "" {
		return domain.ShoppingList{}, ErrMissingRequiredFields
	}
	return uc.Lists.Get(ctx, userID, id)
}

func (uc *ShoppingListUsecase) List(ctx context.Context, userID string, opts repository.ListOptions) ([]domain.ShoppingList, *string, error) {
	if userID == "" {
		return nil, nil, ErrMissingRequiredFields
	}
	return uc.Lists.List(ctx, userID, opts)
}

type ShoppingItemUsecase struct {
	Items repository.ShoppingItemRepository
}

type ShoppingItemUpdateInput struct {
	Title     *string
	Quantity  *string
	Checked   *bool
	SortOrder *int
}

func (uc *ShoppingItemUsecase) Create(ctx context.Context, userID, listID, title string, quantity *string, checked *bool, sortOrder *int) (domain.ShoppingItem, error) {
	title = normalizeString(title)
	if userID == "" || listID == "" || title == "" {
		return domain.ShoppingItem{}, ErrMissingRequiredFields
	}
	order := 0
	if sortOrder != nil {
		if *sortOrder < 0 {
			return domain.ShoppingItem{}, ErrInvalidPayload
		}
		order = *sortOrder
	}
	isChecked := false
	if checked != nil {
		isChecked = *checked
	}

	item := domain.ShoppingItem{
		UserID:    userID,
		ListID:    listID,
		Title:     title,
		Quantity:  normalizeOptionalString(quantity),
		Checked:   isChecked,
		SortOrder: order,
	}

	return uc.Items.Create(ctx, item)
}

func (uc *ShoppingItemUsecase) Update(ctx context.Context, userID, id string, input ShoppingItemUpdateInput) (domain.ShoppingItem, error) {
	if userID == "" || id == "" {
		return domain.ShoppingItem{}, ErrMissingRequiredFields
	}
	item, err := uc.Items.Get(ctx, userID, id)
	if err != nil {
		return domain.ShoppingItem{}, err
	}

	if input.Title != nil {
		trimmed := normalizeString(*input.Title)
		if trimmed == "" {
			return domain.ShoppingItem{}, ErrMissingRequiredFields
		}
		item.Title = trimmed
	}
	if input.Quantity != nil {
		item.Quantity = normalizeOptionalString(input.Quantity)
	}
	if input.Checked != nil {
		item.Checked = *input.Checked
	}
	if input.SortOrder != nil {
		if *input.SortOrder < 0 {
			return domain.ShoppingItem{}, ErrInvalidPayload
		}
		item.SortOrder = *input.SortOrder
	}

	return uc.Items.Update(ctx, item)
}

func (uc *ShoppingItemUsecase) Delete(ctx context.Context, userID, id string) error {
	if userID == "" || id == "" {
		return ErrMissingRequiredFields
	}
	return uc.Items.Delete(ctx, userID, id)
}

func (uc *ShoppingItemUsecase) Get(ctx context.Context, userID, id string) (domain.ShoppingItem, error) {
	if userID == "" || id == "" {
		return domain.ShoppingItem{}, ErrMissingRequiredFields
	}
	return uc.Items.Get(ctx, userID, id)
}

func (uc *ShoppingItemUsecase) ListByList(ctx context.Context, userID, listID string, opts repository.ListOptions) ([]domain.ShoppingItem, *string, error) {
	if userID == "" || listID == "" {
		return nil, nil, ErrMissingRequiredFields
	}
	return uc.Items.ListByList(ctx, userID, listID, opts)
}
