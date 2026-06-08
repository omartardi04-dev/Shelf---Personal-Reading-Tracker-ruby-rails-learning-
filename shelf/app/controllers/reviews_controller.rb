class ReviewsController < ApplicationController
  def create
    @book = current_user.books.find(params[:book_id])
    @review = @book.reviews.build(review_params)
    @review.user = current_user
    if @review.save
      redirect_to @book, notice: "Review was successfully created."
    else
      redirect_to @book, alert: "Failed to create review."
    end
  end
  def destroy
    @book = current_user.books.find(params[:book_id])
    @review = current_user.reviews.find(params[:id])
    @review.destroy
    redirect_to @book, notice: "Review was successfully destroyed."
  end
  private
  def review_params
    params.require(:review).permit(:content, :rating)
  end
end
