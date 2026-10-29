import rclpy
from rclpy.node import Node
from std_msgs.msg import String
from rclpy.qos import (
    QoSProfile,
    QoSReliabilityPolicy,
    QoSHistoryPolicy,
    QoSDurabilityPolicy,
)

class Talker(Node):
    def __init__(self):
        super().__init__('talker') 
        qos = QoSProfile(
            reliability=QoSReliabilityPolicy.RELIABLE,
            history=QoSHistoryPolicy.KEEP_LAST,
            depth=10,
            durability=QoSDurabilityPolicy.VOLATILE,
        )
        self.publisher_ = self.create_publisher(String, 'chatter', qos)
        self.timer = self.create_timer(1.0, self.on_timer)
        self._count = 0

    def on_timer(self):
        msg = String()
        msg.data = f'hello world: {self._count}'
        self.publisher_.publish(msg)
        self.get_logger().info(f'Publishing: "{msg.data}"')
        self._count += 1



def main(args=None):
    rclpy.init(args=args)
    node = Talker()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass  # Ctrl+C is a normal way to stop; exit quietly
    finally:
        node.destroy_node()
        if rclpy.ok():
            rclpy.shutdown()


if __name__ == '__main__':
    main()