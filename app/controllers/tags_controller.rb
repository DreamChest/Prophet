class TagsController < ApplicationController
	before_action :set_tag, only: [:show, :edit, :update, :destroy]
	before_action :set_tags, only: [:index, :create, :update, :destroy]

	# GET /tags
	# GET /tags.json
	def index
	end

	# GET /tags/1
	# GET /tags/1.json
	def show
	end

	# GET /tags/new
	def new
		@tag = Tag.new
	end

	# GET /tags/1/edit
	def edit
	end

	# POST /tags
	# POST /tags.json
	def create
		@tag = Tag.new(tag_params)

		respond_to do |format|
			if @tag.save
				format.html { render :index }
				format.json {
					flash[:notice] = I18n.t("notices.tag_created")
					render :show, status: :created, location: @tag
				}
			else
				format.html { render :new }
				format.json { render json: @tag.errors, status: :unprocessable_entity }
			end
		end
	end

	# PATCH/PUT /tags/1
	# PATCH/PUT /tags/1.json
	def update
		respond_to do |format|
			if @tag.update(tag_params)
				format.html { render :index }
				format.json {
					flash[:notice] = I18n.t("notices.tag_updated")
					render :show, status: :ok, location: @tag
				}
			else
				format.html { render :edit }
				format.json { render json: @tag.errors, status: :unprocessable_entity }
			end
		end
	end

	# DELETE /tags/1
	# DELETE /tags/1.json
	def destroy
		@tag.destroy
		respond_to do |format|
			format.html {
				flash.now[:notice] = I18n.t("notices.tag_destroyed")
				render :index
			}
			format.json { head :no_content }
		end
	end

	private
	# Use callbacks to share common setup or constraints between actions.
	def set_tag
		@tag = Tag.find(params[:id])
	end

	def set_tags
		@tags = Tag.all
	end

	# Never trust parameters from the scary internet, only allow the white list through.
	def tag_params
		params.require(:tag).permit(:name, :color)
	end
end
