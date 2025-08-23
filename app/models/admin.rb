# frozen_string_literal: true

class Admin < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validate :only_one_admin_allowed, on: :create

  private

  def only_one_admin_allowed
    return if Admin.none?

    errors.add(:base, 'Only one admin allowed')
  end
end
