cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE=cc65-toolchain.cmake -B build
cd build
cmake --build .
