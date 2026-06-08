class BooksController < ApplicationController
  def index
    @books = current_user.books
  end
  def show
    @book = current_user.books.find(params[:id])
  end
  def new
    @book = Book.new
  end
  def create
    @book = Book.new(book_params)
    @book.user = current_user
    if @book.save
      redirect_to @book, notice: "Book was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end
  def edit
    @book = current_user.books.find(params[:id])
  end
  def update
    @book = current_user.books.find(params[:id])
    if @book.update(book_params)
      redirect_to @book, notice: "Book was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end
  def destroy
    @book = current_user.books.find(params[:id])
    @book.destroy
    redirect_to books_url, notice: "Book was successfully destroyed."
  end
  private
  def book_params
    params.require(:book).permit(:title, :author, :description, :status)
  end
end
