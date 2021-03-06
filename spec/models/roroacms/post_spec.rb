require 'spec_helper'

RSpec.describe Roroacms::Post, :type => :model do

  before(:each) do
    @tag = FactoryGirl.create(:tag)
    @cat = FactoryGirl.create(:term)
    @post = FactoryGirl.create(:post)
  end

  it "has a valid factory" do
    expect(FactoryGirl.create(:post)).to be_valid
  end

  it "is invalid without a post title" do
    expect(FactoryGirl.build(:post, post_title: nil)).to_not be_valid
  end

  it "is invalid without a unique slug" do
    expect(FactoryGirl.build(:post, post_slug: @post.post_slug)).to_not be_valid
  end

  it "should format the slug to match /\A[A-Za-z0-9\-]*\z/" do
    expect(FactoryGirl.build(:post, post_slug: 'Hesfd sdfd sdf')).to be_valid
  end

  context "title is left blank" do

    it "should create the slug out of the title" do
      expect(FactoryGirl.build(:post, post_slug: nil)).to be_valid
    end
    
  end

  it "should return all pages" do
    FactoryGirl.create(:post, post_type: 'page')
    pages = Roroacms::Post.setup_and_search_posts({}, 'page')
    sample = pages.first[0].post_type
    expect(pages).to_not be_nil
    expect(sample).to eq('page')
  end

  it "should return all posts" do
    posts = Roroacms::Post.setup_and_search_posts({}, 'post')
    sample = posts.sample.post_type
    expect(posts).to_not be_nil
    expect(sample).to eq('post')
  end

  it "should return all tags" do
    tags = Roroacms::Post.get_terms('tag')
    sample = tags.last.name
    expect(sample).to eq(@tag.name)
  end

  it "should return all categories" do
    categories = Roroacms::Post.get_terms('category')
    sample = categories[0].name
    expect(sample).to eq(@cat.name)
  end

  it "should set default values" do
    expect(@post.post_status).to eq('Draft')
    expect(@post.post_slug).to_not be_nil
  end

  context "autosaving" do

    it "should save data in the background as a autosave record" do
      post = Roroacms::Post.create(@post.attributes)
      ret = Roroacms::Post.do_autosave({ post: @post.attributes.symbolize_keys }, post)
      expect(ret).to eq("nothing changed")

      post[:post_title] = 'testing rspec'
      ret = Roroacms::Post.do_autosave({ post: @post.attributes.symbolize_keys }, post)
      expect(ret).to eq("passed")

    end

    it "should save the previous data as a record" do
      p = Roroacms::Post.find(@post.id)
      post_title = p.post_title
      p.post_title = 'fff'

      expect{p.save}.to change(Roroacms::Post,:count).by(1)

    end

  end

  context "bulk updating" do

    before(:each) do
      @record = FactoryGirl.create(:post)
      @array = [@record.id, @post.id]
    end

    it "should set the given recods to published" do
      Roroacms::Post.bulk_update({ to_do: 'publish', pages: @array }, 'pages')

      expect(Roroacms::Post.find(@record.id).post_status).to eq('Published')
      expect(Roroacms::Post.find(@post.id).post_status).to eq('Published')
    end

    it "should set the given records to draft" do
      Roroacms::Post.bulk_update({ to_do: 'draft', pages: @array }, 'pages')

      expect(Roroacms::Post.find(@record.id).post_status).to eq('Draft')
      expect(Roroacms::Post.find(@post.id).post_status).to eq('Draft')
    end

    it "should put the given records into trash" do
      Roroacms::Post.bulk_update({ to_do: 'move_to_trash', pages: @array }, 'pages')

      expect(Roroacms::Post.find(@record.id).disabled).to eq('Y')
      expect(Roroacms::Post.find(@post.id).disabled).to eq('Y')
    end

  end

end
