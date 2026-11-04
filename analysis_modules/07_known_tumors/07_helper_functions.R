transgene_panel_plot <- function(sobj, sample_name, plot_point_size = 0.5) {
  panels <-
    list(
      (DimPlot(
        sobj,
        group.by = "cell_group",
        pt.size = plot_point_size,
        label = TRUE,
        label.box = TRUE,
        label.size = 2,
        repel = TRUE
      ) +
        NoLegend() +
        coord_fixed()),
      (DimPlot(
        sobj,
        group.by = "tumor_cell",
        pt.size = plot_point_size,
        label = TRUE,
        label.box = TRUE,
        label.size = 2,
        repel = TRUE
      ) +
        NoLegend() +
        coord_fixed()),
      (DimPlot(
        sobj,
        group.by = "snv_top_lvl_group_10",
        pt.size = plot_point_size,
        label = TRUE,
        label.box = TRUE,
        label.size = 2,
        repel = TRUE
      ) +
        NoLegend() +
        coord_fixed()),
      (FeaturePlot(
        sobj,
        features = "tumor_marker_count",
        order = TRUE,
        pt.size = plot_point_size
      ) +
        coord_fixed()),
      (ggplot2::ggplot() +
        ggpubr::background_image(
          magick::image_read(
            paste0(
              "output/02_snv_calling/snv/transgene/snvs_",
              sample_name,
              "_10_tree.pdf"
            ),
            density = 300
          )
        ) +
        ggplot2::coord_fixed() +
        ggplot2::labs(y = "Genetic distance (arbitrary units)") +
        theme(
          axis.text.y = element_text(size = 20),
          panel.border = element_blank()
        ))
    )

  plot_layout <- "
    AB
    CD
    EE
    EE
  "
  panel_plot <-
    patchwork::wrap_plots(panels, design = plot_layout) +
    patchwork::plot_annotation(
      title = paste0("Sample: ", sample_name),
      theme = theme(
        plot.title = element_text(hjust = 0.5, size = 24, face = "bold")
      )
    )

  ggplot2::ggsave(
    paste0(
      "output/07_known_tumors/figures/transgene/",
      sample_name,
      "_plots.pdf"
    ),
    plot = panel_plot,
    width = 10,
    height = 18
  )

  return()
}
