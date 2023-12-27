lazy_static::lazy_static! {
    static ref NOTIFY: std::sync::Arc<tokio::sync::Notify> = {
        std::sync::Arc::new(tokio::sync::Notify::new())
    };
}

pub fn get_notify() -> std::sync::Arc<tokio::sync::Notify> {
    NOTIFY.clone()
}

#[flutter_rust_bridge::frb(sync)]
pub fn stop_server() {
    NOTIFY.notify_one();
}
