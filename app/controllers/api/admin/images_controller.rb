# frozen_string_literal: true

module Api
  module Admin
    class ImagesController < ApplicationController
      before_action :authenticate_admin!

      MAX_IMAGE_SIZE = 5.megabytes
      ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/gif image/webp].freeze

      # POST /api/admin/images
      def create
        uploaded_file = params[:image]

        unless uploaded_file.present? && uploaded_file.respond_to?(:content_type)
          return render json: { error: "No image provided" }, status: :unprocessable_entity
        end

        unless ALLOWED_CONTENT_TYPES.include?(uploaded_file.content_type)
          return render json: { error: "Invalid image format. Allowed: JPEG, PNG, GIF, WebP" }, status: :unprocessable_entity
        end

        if uploaded_file.size > MAX_IMAGE_SIZE
          return render json: { error: "Image too large (max 5MB)" }, status: :unprocessable_entity
        end

        blob = ActiveStorage::Blob.create_and_upload!(
          io: uploaded_file,
          filename: uploaded_file.original_filename,
          content_type: uploaded_file.content_type
        )

        url = Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true)

        render json: { url: url, filename: uploaded_file.original_filename }, status: :created
      end
    end
  end
end
