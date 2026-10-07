transgene_panel_plot <- function(sobj, sample_name, plot_point_size = 0.5) {
    panel_plot <-
        ((
            DimPlot(
                sobj,
                group.by = "cell_group",
                pt.size = plot_point_size,
                label = TRUE,
                label.box = TRUE,
                repel = TRUE
            ) +
                NoLegend() +
                coord_fixed()
        ) +
            (
                DimPlot(
                    sobj,
                    group.by = "tumor_cell",
                    pt.size = plot_point_size,
                    label = TRUE,
                    label.box = TRUE,
                    repel = TRUE
                ) +
                    NoLegend() +
                    coord_fixed()
            )) /
            ((
                DimPlot(
                    sobj,
                    group.by = "snv_top_lvl_group_10",
                    pt.size = plot_point_size,
                    label = TRUE,
                    label.box = TRUE,
                    repel = TRUE
                ) +
                    NoLegend() +
                    coord_fixed()
            ) +
                (
                    FeaturePlot(
                        sobj,
                        features = "tumor_marker_count",
                        order = TRUE,
                        pt.size = plot_point_size
                    ) +
                        coord_fixed()
                ))

    ggplot2::ggsave(
        paste0("output/07_known_tumors/figures/transgene/", sample_name, "_plots.pdf"),
        plot = panel_plot,
        width = 15,
        height = 15
    )

    return()
}

