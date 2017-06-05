class SourcesController < ApplicationController
	require "feedjira" # RSS feed fetching and parsing
	require "open-uri" # To get favicon file
	require "open_uri_redirections" # Allow open-uri for unsecured redirections
	require "rmagick" # For convertir favicon ico files into png files
	require "fileutils" # To delete favicon file on source deletion

	before_action :set_source, only: [:show, :edit, :update, :destroy, :show_entries, :update_entries]
	before_action :set_sources, only: [:index, :create, :destroy, :update, :update_entries]
	before_action :set_favicon_file_path, only: [:destroy]

	# GET /sources
	# GET /sources.json
	def index
		respond_to do |format|
			format.html
			format.json
			format.opml
		end
	end

	# GET /sources/1
	# GET /sources/1.json
	def show
		respond_to do |format|
			format.html { redirect_to root_path }
			format.json
		end
	end

	# GET /sources/new
	def new
		@source = Source.new
		@entries = @source.entries.build
		@tags = @source.tags.build
	end

	# GET /sources/1/edit
	def edit
	end

	# POST /sources
	# POST /sources.json
	def create
		@source = Source.new(source_params)

		begin
			feed = Feedjira::Feed.fetch_and_parse(@source.url) if @source.valid?

			respond_to do |format|
				if @source.save
					feed.entries.reverse.each do |e|
						@source.entries.create!(title: e.title, url: e.url, read: false, fav: false, date: e.published, content: Content.create({ html: e.content || e.summary }))
					end

					@source.update(html_url: feed.url, last_update: feed.entries.first.published)

					tag

					begin
						get_favicon
					rescue
						flash[:error] = I18n.t("errors.favicon_error")
					end

					format.html { render :index }
					format.json {
						flash[:notice] = I18n.t("notices.source_created")
						render :show, status: :created, location: @source
					}
				else
					format.html { render :new }
					format.json { render json: @source.errors, status: :unprocessable_entity }
				end
			end
		rescue
			respond_to do |format|
				format.html { render :new }
				format.json { render json: { url: [I18n.t("forms.validations.errors.invalid_feed")] }, status: :unprocessable_entity }
			end
		end
	end

	# PATCH/PUT /sources/1
	# PATCH/PUT /sources/1.json
	def update
		@source.assign_attributes(source_params)

		begin
			url_changed = @source.url_changed?
			feed = Feedjira::Feed.fetch_and_parse(@source.url) if @source.valid? and url_changed

			respond_to do |format|
				if @source.update(source_params)
					unless feed.nil? # If feed is undefined (if URL has not changed)
						@source.entries.each do |e|
							e.content.destroy
						end
						@source.entries.clear

						feed.entries.reverse.each do |e|
							@source.entries.create!(title: e.title, url: e.url, read: false, fav: false, date: e.published, content: Content.create({ html: e.content || e.summary }))
						end

						@source.update(html_url: feed.url, last_update: feed.entries.first.published)
					end

					tag

					# Fetch favicon only if absent or if URL changed
					if @source.favicon.nil? or url_changed
						begin
							get_favicon
						rescue
							flash[:error] = I18n.t("errors.favicon_error")
						end
					end

					format.html { render :index }
					format.json {
						flash[:notice] = I18n.t("notices.source_saved", count: 1)
						render :show, status: :ok, location: @source
					}
				else
					format.html { render :edit }
					format.json { render json: @source.errors, status: :unprocessable_entity }
				end
			end
		rescue
			respond_to do |format|
				format.html { render :new }
				format.json { render json: { url: [I18n.t("forms.validations.errors.invalid_feed")] }, status: :unprocessable_entity }
			end
		end
	end

	# DELETE /sources/1
	# DELETE /sources/1.json
	def destroy
		@source.destroy
		FileUtils.rm(@favicon_file_path) if Dir.exists?(@favicon_file_path)

		respond_to do |format|
			format.html {
				flash.now[:notice] = I18n.t("notices.source_destroyed", name: @source.name)
				render :index
			}
			format.json { head :no_content }
		end
	end

	# Shows entries for the source (JSON only)
	def show_entries
		respond_to do |format|
			format.html { redirect_to controller: "entries", action: "index", source: @source.name }
			format.json { render json: @source.entries }
		end
	end

	# Updates entries for the source
	def update_entries
		begin
			fetch

			flash.now[:notice] = I18n.t("notices.source_updated", count: 1, name: @source.name)
			render :index
		rescue
			flash.now[:error] = I18n.t("errors.invalid_feed", count: 1, name: @source.name)
			render :index
		end
	end

	# Updates all sources (fetches entries for each source)
	def update_all
		last_entry = Entry.order("date DESC").first # Get most recent entry
		failed_sources = []

		Source.all.each do |s|
			@source = s
			begin
				fetch
			rescue
				failed_sources.push(@source.name)
			end
		end

		if last_entry.nil? # If no entries where present before (first update)...
			new_entries = Entry.order("date DESC") # ... then all entries are kept and considered new
		else
			new_entries = Entry.where("date > ?", last_entry.date).order("date DESC") # ... else, only more recent entries are kept and considered new
		end

		details = "#{new_entries.size} #{I18n.t("notices.new_entries", count: new_entries.size)}"

		if new_entries.empty? # If there are no new entries...
			@entries = Entry.order("date DESC").limit(ENTRIES_LIMIT) # ... then display entries normally
		else
			@filter = details
			@entries = new_entries # ... else, display new entries
		end

		flash.now[:notice] = I18n.t("notices.source_updated", count: 2, details: details)

		unless failed_sources.empty?
			flash.now[:error] = I18n.t("errors.invalid_feed", count: failed_sources.size, name: failed_sources.join(", "))
		end

		render "entries/index"
	end

	private
	# Tags the source
	def tag
		unless params[:source]["tagslist_attr"].empty?
			params[:source]["tagslist_attr"].split(',').each do |t|
				tag = Tag.where("name = ?", t).take # Pull take from DB if it exists...
				if tag.nil?
					@source.tags.create!(name: t, color: "#ffffff") # ... else create it and tag the source with it
				else
					@source.tags<<(tag) unless @source.tags.exists?(tag.id) # Tag source unless its already tagged with this tag
				end
			end
		else
			@source.tags.clear
		end
	end

	# Gets the favicon for the source
	def get_favicon
		set_favicon_file_path

		uri = "#{@source.html_url}/favicon.ico"

		open(Prophet::FAVICON_TEMP_PATH, "wb") do |file|
			file << open(uri, allow_redirections: :all).read
		end

		ico = Magick::Image::read(Prophet::FAVICON_TEMP_PATH).first
		ico.write(@favicon_file_path)

		@source.update(favicon: "#{Prophet::FAVICON_BASE_URL}#{@favicon_file_name}")
	end

	# Fetches and saves the new entries
	def fetch
		feed = Feedjira::Feed.fetch_and_parse(@source.url)

		feed.entries.reverse.each do |e|
			if e.published > @source.last_update
				@source.entries.create!(title: e.title, url: e.url, read: false, fav: false, date: e.published, content: Content.create({ html: e.content || e.summary }))
			end
		end

		@source.update(html_url: feed.url, last_update: feed.entries.first.published)

		if @source.favicon.nil?
			begin
				get_favicon
			rescue
				flash.now[:error] = I18n.t("errors.favicon_error")
			end
		end
	end

	# Use callbacks to share common setup or constraints between actions.
	def set_source
		@source = Source.find(params[:id])
	end

	def set_sources
		@sources = Source.all
	end

	def set_favicon_file_path
		@favicon_file_name = "#{@source.id}.png"
		@favicon_file_path = "#{Prophet::FAVICONS_DIR_PATH}/#{@favicon_file_name}"
	end

	# Never trust parameters from the scary internet, only allow the white list through.
	def source_params
		params.require(:source).permit(:name, :url, :tagslist_attr)
	end
end
