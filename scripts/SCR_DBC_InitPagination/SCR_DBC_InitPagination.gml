function SCR_DBC_InitPagination() {
    current_page = 0;
    cards_per_page = grid_cols_visible * grid_rows_visible;
    total_pages = SCR_DBD_GetCollectionPageCount(cards_per_page);
}