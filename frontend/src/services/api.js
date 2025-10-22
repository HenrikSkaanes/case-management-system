/**
 * API service for communicating with the backend Container App.
 * 
 * The API URL is configured via environment variable (VITE_API_URL).
 * In Static Web App, this will be set during deployment.
 */

// Get API URL from environment variable
// For Static Web App, this will be: https://ca-api-xxx.norwayeast.azurecontainerapps.io/api
// For local dev, this falls back to localhost
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api';

console.log('🌐 API Base URL:', API_BASE_URL);

/**
 * Fetch all tickets
 */
export const fetchTickets = async () => {
  try {
    const response = await fetch(`${API_BASE_URL}/tickets/`);
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    return await response.json();
  } catch (error) {
    console.error('❌ Error fetching tickets:', error);
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
    console.error('❌ Error creating ticket:', error);
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
    console.error('❌ Error updating ticket:', error);
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
    console.error('❌ Error deleting ticket:', error);
    throw error;
  }
};
