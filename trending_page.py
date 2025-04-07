import streamlit as st
import requests
from app_main import fetch_movie_poster
import favorite_adder
from logger import log_movie_click

# API Endpoint to fetch favorite movies
trending_API_URL = "http://localhost:8080/api/trending"

def fetch_trending_movies():
    """Fetch favorite movies for the given user ID."""
    try:
        response = requests.get(f"{trending_API_URL}")
        if response.status_code == 200:
            return response.json()
        else:
            st.error(f"Error fetching trending: {response.status_code}")
            return []
    except Exception as e:
        st.error(f"Failed to connect to the API: {e}")
        return []

def display_movie_cards_trendingpage(movies):
    """Display movie details in a card-style format with review & favorite options"""
    if not movies:
        st.warning("No movies found.")
        return

    cols = st.columns(2)  # Display in two columns

    for index, movie in enumerate(movies):
        if not isinstance(movie, dict):  # Ensure movie is a dictionary
            continue

        movie_id = movie.get("id", index)
        movie_name = movie.get("name", "Unknown")

        with cols[index % 2]:  # Alternate between columns
            poster_url = fetch_movie_poster(movie_name)
            if poster_url:
                st.image(poster_url, width=200)

                        # ✅ Make entire card clickable
            if st.button(movie_name, key=f"movie_{movie_id}"):
                st.session_state["selected_movie"] = movie
                user_id = st.session_state.get("user_id")
                log_movie_click(user_id, movie["id"])
                st.rerun()  # Refresh page to load movie details

            st.markdown(
                f"""
                <div style="border-radius: 10px; padding: 15px; margin-bottom: 20px; background-color: #f0f0f0; padding-top: 10px;">
                    <p><b>Category:</b> {movie.get('category', 'N/A')}</p>
                    <p><b>IMDB Rating:</b> ⭐ {movie.get('imdbrating', 'N/A')}</p>
                    <p><b>Release Date:</b> {movie.get('releaseDate', 'N/A')[:10]}</p>
                    <p><b>OTT Available:</b> {'✅ Yes' if movie.get('ottAvailable', False) else '❌ No'}</p>
                    <p>{movie.get('description', 'No description available.')}</p>
                    <p><b>User Rating:</b> 🔷 {movie.get('userRating') if movie.get('userRating') is not None else 'N/A'}</p>
                    <p><b>User Review:</b>{movie.get('userReview', 'No description available.')}</p>
                </div>
                """, unsafe_allow_html=True
            )




def trending_page():
    """Display the user's favorite movies."""
    
    # Ensure user is authenticated
    if "authenticated" not in st.session_state or not st.session_state["authenticated"]:
        st.warning("⚠ Please log in first!")
        return
    
    user_id = st.session_state.get("user_id")
    if not user_id:
        st.error("User ID not found. Please log in again.")
        return
    
    trending_movies = fetch_trending_movies()
    display_movie_cards_trendingpage(trending_movies)

if __name__ == "__main__":
    trending_page()
