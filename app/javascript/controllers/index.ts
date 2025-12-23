import { Application } from "@hotwired/stimulus"

import ThemeController from "./theme_controller"
import DropdownController from "./dropdown_controller"
import SdkIntegrationController from "./sdk_integration_controller"
import ClipboardController from "./clipboard_controller"
import ProfileChatController from "./profile_chat_controller"
import ProfileOnboardingController from "./profile_onboarding_controller"
import DashboardAssistantController from "./dashboard_assistant_controller"
import WechatShareController from "./wechat_share_controller"
import ImagePreviewController from "./image_preview_controller"
import ImageFallbackController from "./image_fallback_controller"
import TeamInviteController from "./team_invite_controller"
import BottomNavController from "./bottom_nav_controller"

const application = Application.start()

application.register("theme", ThemeController)
application.register("dropdown", DropdownController)
application.register("sdk-integration", SdkIntegrationController)
application.register("clipboard", ClipboardController)
application.register("profile-chat", ProfileChatController)
application.register("profile-onboarding", ProfileOnboardingController)
application.register("dashboard-assistant", DashboardAssistantController)
application.register("wechat-share", WechatShareController)
application.register("image-preview", ImagePreviewController)
application.register("image-fallback", ImageFallbackController)
application.register("team-invite", TeamInviteController)
application.register("bottom-nav", BottomNavController)

window.Stimulus = application
