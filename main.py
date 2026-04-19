import threading
import os
import time

class ParallelFileReader:
    def __init__(self, file_paths):
        self.file_paths = file_paths
        self.lock = threading.Lock()
        self.read_files = []

    def read_file(self, file_path):
        with open(file_path, 'r') as file:
            content = file.read()
            with self.lock:
                self.read_files.append(content)

    def start_reading(self):
        threads = []
        for file_path in self.file_paths:
            thread = threading.Thread(target=self.read_file, args=(file_path,))
            threads.append(thread)
            thread.start()

        for thread in threads:
            thread.join()

    def get_read_files(self):
        return self.read_files

class FileProcessor:
    def __init__(self, file_paths):
        self.file_paths = file_paths
        self.reader = ParallelFileReader(file_paths)

    def process_files(self):
        self.reader.start_reading()
        return self.reader.get_read_files()

def main():
    file_paths = ['file1.txt', 'file2.txt', 'file3.txt']
    processor = FileProcessor(file_paths)
    read_files = processor.process_files()
    for i, content in enumerate(read_files):
        print(f"File {i+1} content:")
        print(content)
        print()

if __name__ == "__main__":
    main()
    current_dir = os.getcwd()
    print(f"Current directory: {current_dir}")
    time.sleep(1)
    print("File reading completed")