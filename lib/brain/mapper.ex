import XmlBuilder

defmodule Brain.Mapper do
  @moduledoc """
  Brain API response mapper
  """

  def map_resp_list_buckets(data) do
    xml_bucket_list =
      Enum.map(
        data.buckets,
        fn bucket ->
          element(
            :Bucket,
            [
              element(:CreationDate, bucket.creation_date),
              element(:Name, bucket.name)
            ]
          )
        end
      )

    element(
      :ListAllMyBucketsResult,
      [
        element(:Buckets, xml_bucket_list),
        element(:Prefix, data.prefix)
      ]
    )
  end

  def map_resp_list_objects(data) do
    xml_object_list =
      Enum.map(
        data.contents,
        fn c ->
          element(
            :Contents,
            [
              element(:Key, c.key),
              element(:LastModified, c.last_modified),
              element(:Size, c.size),
              element(:StorageClass, c.storage_class)
            ]
          )
        end
      )

    element(
      :ListBucketResult,
      Enum.concat(
        [
          element(:Name, data.name),
          element(:Prefix, data.prefix),
          element(:KeyCount, data.key_count),
          element(:IsTruncated, data.is_truncated)
        ],
        xml_object_list
      )
    )
  end

  def map_resp_copy_object(data) do
    element(
      :CopyObjectResult,
      [
        element(:LastModified, data.last_modified),
        element(:ChecksumSHA1, data.checksum_sha1)
      ]
    )
  end
end
