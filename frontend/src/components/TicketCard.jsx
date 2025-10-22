import { useState } from 'react';
import './TicketCard.css';

/**
 * TicketCard - Individual ticket component with drag-and-drop support
 * 
 * Displays ticket information in a card format.
 * Supports dragging to different columns.
 * Allows employees to respond to customers via email.
 */
const TicketCard = ({ ticket, onEdit, onDelete, onRespond }) => {
  const [isExpanded, setIsExpanded] = useState(false);
  const [responseText, setResponseText] = useState('');
  const [isSendingResponse, setIsSendingResponse] = useState(false);

  const handleDragStart = (e) => {
    e.dataTransfer.effectAllowed = 'move';
    e.dataTransfer.setData('text/html', e.target);
    e.dataTransfer.setData('ticketId', ticket.id);
  };

  const getPriorityClass = (priority) => {
    switch (priority) {
      case 'critical':
        return 'priority-critical';
      case 'high':
        return 'priority-high';
      case 'medium':
        return 'priority-medium';
      case 'low':
        return 'priority-low';
      default:
        return 'priority-medium';
    }
  };

  const getPriorityIcon = (priority) => {
    switch (priority) {
      case 'critical':
        return '🔴';
      case 'high':
        return '�';
      case 'medium':
        return '🟡';
      case 'low':
        return '🟢';
      default:
        return '⚪';
    }
  };

  const handleSendResponse = async (e) => {
    e.stopPropagation();
    if (!responseText.trim()) {
      alert('Please enter a response');
      return;
    }
    
    setIsSendingResponse(true);
    try {
      // Call the onRespond callback with ticket info and response
      await onRespond(ticket.id, {
        customer_email: ticket.customer_email,
        customer_name: ticket.customer_name,
        ticket_title: ticket.title,
        response: responseText
      });
      
      setResponseText('');
      alert('Response sent successfully!');
    } catch (error) {
      console.error('Error sending response:', error);
      alert('Failed to send response. Please try again.');
    } finally {
      setIsSendingResponse(false);
    }
  };

  return (
    <div
      className={`ticket-card ${getPriorityClass(ticket.priority)}`}
      draggable="true"
      onDragStart={handleDragStart}
      onClick={() => setIsExpanded(!isExpanded)}
    >
      <div className="ticket-header">
        <span className="ticket-id">#{ticket.id}</span>
        <span className={`ticket-priority ${getPriorityClass(ticket.priority)}`}>
          {getPriorityIcon(ticket.priority)} {ticket.priority}
        </span>
      </div>
      
      <h3 className="ticket-title">{ticket.title}</h3>
      
      <div className="ticket-category">
        <span className="category-badge">{ticket.category}</span>
      </div>

      {ticket.customer_name && (
        <div className="ticket-customer">
          <span className="customer-icon">👤</span>
          <span className="customer-name">{ticket.customer_name}</span>
        </div>
      )}

      {isExpanded && (
        <div className="ticket-details">
          <p className="ticket-description">{ticket.description || 'No description provided'}</p>
          
          {ticket.customer_email && (
            <div className="customer-info-section">
              <h4>Customer Information</h4>
              <p><strong>Name:</strong> {ticket.customer_name}</p>
              <p><strong>Email:</strong> {ticket.customer_email}</p>
              {ticket.customer_phone && <p><strong>Phone:</strong> {ticket.customer_phone}</p>}
            </div>
          )}

          <div className="response-section">
            <h4>📧 Send Response to Customer</h4>
            <textarea
              className="response-textarea"
              placeholder="Type your response here..."
              value={responseText}
              onChange={(e) => setResponseText(e.target.value)}
              onClick={(e) => e.stopPropagation()}
              rows="4"
            />
            <button 
              className="btn-send-response"
              onClick={handleSendResponse}
              disabled={isSendingResponse || !responseText.trim()}
            >
              {isSendingResponse ? '📤 Sending...' : '📧 Send Email Response'}
            </button>
          </div>

          <div className="ticket-meta">
            <small>Created: {new Date(ticket.created_at).toLocaleDateString()}</small>
            {ticket.updated_at && ticket.updated_at !== ticket.created_at && (
              <small> • Updated: {new Date(ticket.updated_at).toLocaleDateString()}</small>
            )}
          </div>
          
          <div className="ticket-actions">
            <button 
              className="btn-edit"
              onClick={(e) => {
                e.stopPropagation();
                onEdit(ticket);
              }}
            >
              ✏️ Edit
            </button>
            <button 
              className="btn-delete"
              onClick={(e) => {
                e.stopPropagation();
                if (confirm(`Delete ticket #${ticket.id}?`)) {
                  onDelete(ticket.id);
                }
              }}
            >
              🗑️ Delete
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default TicketCard;

