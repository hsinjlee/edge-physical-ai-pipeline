from setuptools import find_packages, setup

package_name = 'edge_bringup'

setup(
    name=package_name,
    version='0.0.1',
    packages=find_packages(exclude=['test']),
    data_files=[
        ('share/ament_index/resource_index/packages',
            ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='hsinjlee',
    maintainer_email='rlee4408@gmail.com',
    description='Week 1 ROS 2 fundamentals: minimal talker/listener pair',
    license='Apache-2.0',
    tests_require=['pytest'],
    entry_points={
        'console_scripts': [
            'talker = edge_bringup.talker:main',
            'listener = edge_bringup.listener:main',
        ],
    },
)
