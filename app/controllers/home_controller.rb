class HomeController < ApplicationController
  include RecipesHelper
  include UsersHelper

  def index
    if user_signed_in?
      followed_users = current_user.following
      @events = followed_users.map { |user| user.events.last(5) }.flatten.sort { |a, b| b.created_at <=> a.created_at }
      redirect_to :browse if @events.empty?
    else
      redirect_to :browse
    end
  end

  def search
    query = params[:query]
    results  = PgSearch.multisearch(query)
    @recipes = Recipe.find_all_by_id(results.map(&:searchable_id))
  end

  def browse
    if cookies["visited"].nil?
      cookies["visited"] = true
      redirect_to "/browse#guider=first"
    end

    @images = Rails.cache.fetch("popular_images", :expires_in => 5.minutes) do
      recipe_images = RecipeImage.joins("join recipes on recipes.id = recipe_images.recipes_id").last(50)
      recipes = Recipe.find_all_by_id(recipe_images.map(&:recipes_id))

      recipe_images.map { |i| i.image_url(:thumb) }.zip(recipes)
    end
  end
end
