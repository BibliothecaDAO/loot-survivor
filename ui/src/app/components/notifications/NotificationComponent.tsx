import { useState, useEffect } from "react";
import SpriteAnimation from "@/app/components/animations/SpriteAnimation";
import { notificationAnimations } from "@/app/lib/constants";
import useLoadingStore from "@/app/hooks/useLoadingStore";
import { CSSTransition } from "react-transition-group";
import { Button } from "@/app/components/buttons/Button";

export interface NotificationComponentProps {
  notifications: any[];
}

const NotificationComponent = ({
  notifications,
}: NotificationComponentProps) => {
  const resetNotification = useLoadingStore((state) => state.resetNotification);
  const showNotification = useLoadingStore((state) => state.showNotification);
  const error = useLoadingStore((state) => state.error);
  const errorMessage = useLoadingStore((state) => state.errorMessage);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [flash, setFlash] = useState(false);

  useEffect(() => {
    if (currentIndex < notifications.length - 1) {
      const timer = setTimeout(() => {
        setCurrentIndex((prev) => prev + 1);
      }, 2000);
      return () => {
        clearTimeout(timer);
      };
    } else if (currentIndex === notifications.length - 1) {
      const timer = setTimeout(() => {
        resetNotification();
      }, 2000);
      return () => clearTimeout(timer);
    }
  }, [showNotification, currentIndex]);

  useEffect(() => {
    setFlash(true);
    const timer = setTimeout(() => {
      setFlash(false);
    }, 500);
    return () => clearTimeout(timer);
  }, [currentIndex]);

  useEffect(() => {
    if (showNotification) {
      setCurrentIndex(0);
    }
  }, [showNotification]);

  const copyToClipboard = async (text: string) => {
    try {
      await navigator.clipboard.writeText(text);
    } catch (err) {
      console.error("Failed to copy text: ", err);
    }
  };

  return (
    <CSSTransition
      in={showNotification}
      timeout={300}
      classNames="notification"
      unmountOnExit
    >
      <div
        className={`fixed top-1/16 left-auto w-[90%] sm:left-3/8 sm:w-1/4 border-4 z-50 shadow-xl bg-terminal-black ${
          error ? "border-red-600" : "border-terminal-green"
        }`}
      >
        <div className="relative flex flex-row w-full gap-5 sm:p-2">
          {flash && <div className="notification-flash" />}
          <div className="sm:hidden w-1/6 sm:w-1/4">
            <SpriteAnimation
              frameWidth={80}
              frameHeight={80}
              columns={7}
              rows={16}
              frameRate={5}
              animations={notificationAnimations}
              currentAnimation={notifications[currentIndex]?.animation}
              className="notification-sprite"
              adjustment={10}
            />
          </div>
          <div className="w-1/6 sm:w-1/4 hidden sm:block">
            <SpriteAnimation
              frameWidth={100}
              frameHeight={100}
              columns={7}
              rows={16}
              frameRate={5}
              animations={notificationAnimations}
              currentAnimation={notifications[currentIndex]?.animation}
              className="notification-sprite"
              adjustment={10}
            />
          </div>
          <div className="w-2/3 sm:w-3/4 m-auto text-sm sm:text-lg">
            {notifications[currentIndex]?.message}
          </div>
          {error && (
            <Button onClick={() => copyToClipboard(errorMessage ?? "")}>
              Copy Error
            </Button>
          )}
        </div>
      </div>
    </CSSTransition>
  );
};

export default NotificationComponent;
