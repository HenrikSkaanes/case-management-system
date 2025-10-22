/**
 * API service for communicating with the backend.
 * 
 * All API calls to the FastAPI backend go through these functions.
 * Handles errors and provides consistent interface.
 */

// Use relative URL in production (same server), localhost in development
const API_BASE_URL = import.meta.env.PROD 
  ? '/api'  // Production: relative URL (same container)
  : 'http://localhost:8000/api';  // Development: local backend

/**
 * Fetch all tickets with optional filters
 */
export const fetchTickets = async (filters = {}) => {
  try {
    const params = new URLSearchParams(filters);
    const response = await fetch(`${API_BASE_URL}/tickets/?${params}`);
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    return await response.json();
  } catch (error) {
    console.error('Error fetching tickets:', error);
    throw error;
  }
};

/**
 * Create a new ticket
 */
export const createTicket = async (ticketData) => {
  try {
    const response = await fetch(`${API_BASE_URL}/tickets/`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(ticketData),
    });
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    return await response.json();
  } catch (error) {
    console.error('Error creating ticket:', error);
    throw error;
  }
};

/**
 * Update an existing ticket
 */
export const updateTicket = async (ticketId, updates) => {
  try {
    const response = await fetch(`${API_BASE_URL}/tickets/${ticketId}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(updates),
    });
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    return await response.json();
  } catch (error) {
    console.error('Error updating ticket:', error);
    throw error;
  }
};

/**
 * Delete a ticket
 */
export const deleteTicket = async (ticketId) => {
  try {
    const response = await fetch(`${API_BASE_URL}/tickets/${ticketId}`, {
      method: 'DELETE',
    });
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    return true;
  } catch (error) {
    console.error('Error deleting ticket:', error);
    throw error;
  }
};
