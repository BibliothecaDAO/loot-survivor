import { useState, useEffect } from "react";
import SpriteAnimation from "./SpriteAnimation";
import { useMediaQuery } from "react-responsive";
import { notificationAnimations } from "@/app/lib/constants";

export interface NotificationComponentProps {
  notifications: any[];
}

const NotificationComponent = ({
  notifications,
}: NotificationComponentProps) => {
  const [currentIndex, setCurrentIndex] = useState(0);

  const isMobileDevice = useMediaQuery({
    query: "(max-device-width: 480px)",
  });

  useEffect(() => {
    if (currentIndex < notifications.length - 1) {
      const timer = setTimeout(() => {
        setCurrentIndex((prevIndex) => prevIndex + 1);
      }, 5000);
      return () => clearTimeout(timer);
    }
  }, [currentIndex]);

  return (
    <div className="z-10 flex flex-row w-full gap-5 sm:p-2">
      <div className="w-1/6 sm:w-1/4">
        <SpriteAnimation
          frameWidth={isMobileDevice ? 80 : 100}
          frameHeight={isMobileDevice ? 80 : 100}
          columns={7}
          rows={16}
          frameRate={5}
          animations={notificationAnimations}
          currentAnimation={notifications[currentIndex].animation}
        />
      </div>
      <div className="w-5/6 sm:w-3/4 m-auto text-sm sm:text-lg">
        {notifications[currentIndex].message}
      </div>
    </div>
  );
};

export default NotificationComponent;
