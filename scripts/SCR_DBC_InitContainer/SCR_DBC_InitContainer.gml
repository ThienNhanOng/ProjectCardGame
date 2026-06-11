function SCR_DBC_InitContainer() {
    container_x = grid_start_x - 10;
    container_y = grid_start_y - 10;
    container_w = grid_cols_visible * (card_w + grid_padding_x) + 20;
    container_h = grid_rows_visible * (card_h + grid_padding_y) + 20;
}