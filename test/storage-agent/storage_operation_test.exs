defmodule StorageOperationTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  @test_file_path "#{System.tmp_dir()}/test_file.txt"
  @test_dir_path "#{System.tmp_dir()}/test_dir"

  setup do
    File.rm(@test_file_path)
    File.rm_rf(@test_dir_path)
    :ok
  end

  describe "write/2" do
    test "successfully writes data to a file" do
      data = "Hello, world!"

      assert :ok == StorageOperation.write(@test_file_path, data)

      assert File.exists?(@test_file_path)
      assert File.read!(@test_file_path) == data
    end

    test "logs info on successful write" do
      data = "Hello, world!"

      log =
        capture_log(fn ->
          StorageOperation.write(@test_file_path, data)
        end)

      assert log =~ "Successfully wrote data to #{@test_file_path}"
    end
  end

  describe "read/1" do
    test "successfully reads data from a file" do
      data = "Hello, world!"
      File.write!(@test_file_path, data)

      assert {:ok, ^data} = StorageOperation.read(@test_file_path)
    end

    test "logs info on successful read" do
      data = "Hello, world!"
      File.write!(@test_file_path, data)

      log =
        capture_log(fn ->
          StorageOperation.read(@test_file_path)
        end)

      assert log =~ "Successfully read data from #{@test_file_path}"
    end

    test "returns error if file does not exist" do
      assert {:error, "Failed to read data"} = StorageOperation.read(@test_file_path)
    end

    test "logs error if read fails" do
      log =
        capture_log(fn ->
          StorageOperation.read(@test_file_path)
        end)

      assert log =~ "Failed to read data from #{@test_file_path}:"
    end
  end

  describe "delete/1" do
    test "successfully deletes a file" do
      File.write!(@test_file_path, "Some content")

      assert :ok == StorageOperation.delete(@test_file_path)

      refute File.exists?(@test_file_path)
    end

    test "logs info on successful deletion" do
      File.write!(@test_file_path, "Some content")

      log =
        capture_log(fn ->
          StorageOperation.delete(@test_file_path)
        end)

      assert log =~ "Successfully deleted file #{@test_file_path}"
    end

    test "returns error if file does not exist" do
      assert {:error, "Failed to delete file"} = StorageOperation.delete(@test_file_path)
    end
  end
end
