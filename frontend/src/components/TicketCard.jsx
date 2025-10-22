import { useState } from 'react';
import './TicketCard.css';

/**
 * TicketCard - Individual ticket component with drag-and-drop support
 * 
 * Displays ticket information in a card format.
 * Supports dragging to different columns.
 */
const TicketCard = ({ ticket, onEdit, onDelete }) => {
  const [isExpanded, setIsExpanded] = useState(false);

  const handleDragStart = (e) => {
    e.dataTransfer.effectAllowed = 'move';
    e.dataTransfer.setData('text/html', e.target);
    e.dataTransfer.setData('ticketId', ticket.id);
  };

  const getPriorityClass = (priority) => {
    switch (priority) {
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
      case 'high':
        return '🔴';
      case 'medium':
        return '🟡';
      case 'low':
        return '🟢';
      default:
        return '⚪';
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

      {isExpanded && (
        <div className="ticket-details">
          <p className="ticket-description">{ticket.description || 'No description provided'}</p>
          <div className="ticket-meta">
            <small>Created: {new Date(ticket.created_at).toLocaleDateString()}</small>
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
