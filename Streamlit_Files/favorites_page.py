import streamlit as st
import requests
from app_main import fetch_movie_poster
import favorite_adder
from logger import log_movie_click

# API Endpoint to fetch favorite movies
FAVORITES_API_URL = "http://localhost:8080/favorites/get"

def fetch_favorite_movies(user_id):
    """Fetch favorite movies for the given user ID."""
    try:
        response = requests.post(f"{FAVORITES_API_URL}?userId={user_id}")
        if response.status_code == 200:
            return response.json()
        else:
            st.error(f"Error fetching favorites: {response.status_code}")
            return []
    except Exception as e:
        st.error(f"Failed to connect to the API: {e}")
        return []

def display_movie_cards_favpage(movies, title="🎬 Movies List"):
    """Display movie details in a card-style format with review & favorite options"""
    if not movies:
        st.warning("No movies found.")
        return

    st.title(title)

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

            # ✅ Favorite Button
            #fav_button = st.button("❤️", key=f"fav_{movie_id}", help="Add to Favorites")
            if st.button("❌", key=f"del_fav_{movie_id}", help="Remove from Favorites"):
                favorite_adder.remove_from_favorites(st.session_state["user_id"], movie_id)
                st.rerun



def favorites_page():
    """Display the user's favorite movies."""
    st.title("❤️ Your Favorites")
    
    # Ensure user is authenticated
    if "authenticated" not in st.session_state or not st.session_state["authenticated"]:
        st.warning("⚠ Please log in first!")
        return
    
    user_id = st.session_state.get("user_id")
    if not user_id:
        st.error("User ID not found. Please log in again.")
        return
    
    favorite_movies = fetch_favorite_movies(user_id)
    display_movie_cards_favpage(favorite_movies)

if __name__ == "__main__":
    favorites_page()
