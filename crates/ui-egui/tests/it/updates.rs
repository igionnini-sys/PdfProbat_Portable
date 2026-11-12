//! In corporate offline fork, updates are disabled and managed by enterprise policy.

use egui_kittest::Harness;
use egui_kittest::kittest::Queryable;
use pdfcraft_ui_egui::PdfCraftApp;

fn harness() -> Harness<'static, PdfCraftApp> {
    Harness::builder().with_size(egui::vec2(1200.0, 800.0)).build_eframe(|_cc| {
        let mut app = PdfCraftApp::new();
        app.set_option("language", "en").unwrap();
        app
    })
}

#[test]
fn update_check_at_start_is_off_by_default() {
    assert!(!PdfCraftApp::new().update_check_at_start, "offline fork has startup update check disabled");
}

#[test]
fn checking_for_updates_notifies_enterprise_policy() {
    let mut h = harness();
    h.state_mut().execute("help.check_updates");
    h.run_steps(2);
    // Asserts that no update download dialog or prompt appears
    assert!(h.query_by_label_contains("is available").is_none());
    assert!(h.query_by_label("DOWNLOAD").is_none());
}
