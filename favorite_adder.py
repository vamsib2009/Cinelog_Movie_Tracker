import requests
import streamlit as st

# API Endpoint for adding favorites
ADD_FAVORITE_API_URL = "http://localhost:8080/favorites/add"
DELETE_FAVORITE_API_URL = "http://localhost:8080/favorites/delete"


def add_to_favorites(user_id, movie_id):
    """Send a request to add a movie to the user's favorites."""
    response = requests.post(
        ADD_FAVORITE_API_URL, params={"userId": user_id, "movieId": movie_id}
    )
    
    if response.status_code == 200:
        st.success("✅ Movie added to favorites!")
    else:
        st.error("❌ Failed to add movie to favorites. It may already be in favorites.")


def remove_from_favorites(user_id, movie_id):
    """Send a request to add a movie to the user's favorites."""
    response = requests.post(
        DELETE_FAVORITE_API_URL, params={"userId": user_id, "movieId": movie_id}
    )
    
    if response.status_code == 200:
        st.success("✅ Movie deleted from favorites!")
    else:
        st.error("❌ Failed to delete movie")