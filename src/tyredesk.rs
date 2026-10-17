//! Tyresoles distribution defaults. Authentication and transport remain upstream.
use base::config::keys;
use hbb_common::config;
use std::sync::Once;

static INIT: Once = Once::new();

pub fn init() {
    INIT.call_once(|| {
        *config::APP_NAME.write().unwrap() = "TyreDesk".to_owned();

        // Empty server settings select RustDesk's built-in public servers.
        let server = option_env!("TYREDESK_SERVER").unwrap_or("");
        let key = option_env!("TYREDESK_SERVER_KEY").unwrap_or("");
        config::DEFAULT_SETTINGS.write().unwrap().extend([
            (
                keys::OPTION_CUSTOM_RENDEZVOUS_SERVER.to_owned(),
                server.to_owned(),
            ),
            (keys::OPTION_RELAY_SERVER.to_owned(), server.to_owned()),
            (keys::OPTION_KEY.to_owned(), key.to_owned()),
        ]);

        config::OVERWRITE_SETTINGS.write().unwrap().extend([
            (keys::OPTION_APPROVE_MODE.to_owned(), "password".to_owned()),
            (
                keys::OPTION_VERIFICATION_METHOD.to_owned(),
                "use-permanent-password".to_owned(),
            ),
        ]);
        config::HARD_SETTINGS.write().unwrap().extend([
            ("disable-account".to_owned(), "Y".to_owned()),
            ("disable-ab".to_owned(), "Y".to_owned()),
        ]);
        config::DEFAULT_LOCAL_SETTINGS.write().unwrap().extend([
            (keys::OPTION_LANGUAGE.to_owned(), "pt-br".to_owned()),
            (keys::OPTION_DISABLE_GROUP_PANEL.to_owned(), "Y".to_owned()),
            (keys::OPTION_ENABLE_TCP_PUNCH.to_owned(), "Y".to_owned()),
        ]);
        // Upstream updates would replace this distribution with the stock client.
        config::OVERWRITE_LOCAL_SETTINGS.write().unwrap().insert(
            keys::OPTION_ENABLE_CHECK_UPDATE.to_owned(),
            "N".to_owned(),
        );
        config::OVERWRITE_SETTINGS.write().unwrap().insert(
            keys::OPTION_ALLOW_AUTO_UPDATE.to_owned(),
            "N".to_owned(),
        );
    });
}

#[cfg(test)]
mod tests {
    #[test]
    fn unattended_access_requires_a_permanent_password_without_an_account() {
        super::init();
        assert_eq!(
            hbb_common::config::Config::get_option("approve-mode"),
            "password"
        );
        assert_eq!(
            hbb_common::config::Config::get_option("verification-method"),
            "use-permanent-password"
        );
        assert!(hbb_common::config::is_disable_account());
        assert!(hbb_common::config::is_disable_ab());
        assert!(crate::get_tcp_punch_enabled());
    }
}
