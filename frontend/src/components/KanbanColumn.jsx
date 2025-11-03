import { useState } from 'react';
import TicketCard from './TicketCard';
import './KanbanColumn.css';

/**
 * KanbanColumn - A single column in the Kanban board
 * 
 * Displays tickets for a specific status
 * Handles drop events to update ticket status
 * Supports dynamic styling based on stage color
 */
const KanbanColumn = ({ status, title, tickets, onUpdateTicket, onEditTicket, onDeleteTicket, onRespond, icon, color }) => {
  const [isDragOver, setIsDragOver] = useState(false);

  const handleDragOver = (e) => {
    e.preventDefault();
    setIsDragOver(true);
  };

  const handleDragLeave = () => {
    setIsDragOver(false);
  };

  const handleDrop = async (e) => {
    e.preventDefault();
    setIsDragOver(false);

    const ticketId = e.dataTransfer.getData('ticketId');
    if (ticketId) {
      // Map the column status to the actual ticket status
      const statusMap = {
        'new': 'new',
        'ai_draft': 'ai_draft',
        'in_review': 'in_review',
        'in_progress': 'in_progress',
        'awaiting_customer': 'awaiting_customer',
        'resolved': 'resolved',
        'closed': 'closed'
      };
      await onUpdateTicket(parseInt(ticketId), { status: statusMap[status] || status });
    }
  };

  const getStatusClass = (status) => {
    switch (status) {
      case 'new':
        return 'status-new';
      case 'ai_draft':
        return 'status-ai-draft';
      case 'in_review':
        return 'status-in-review';
      case 'in_progress':
        return 'status-progress';
      case 'awaiting_customer':
        return 'status-awaiting';
      case 'resolved':
        return 'status-resolved';
      case 'closed':
        return 'status-closed';
      default:
        return '';
    }
  };

  return (
    <div 
      className={`kanban-column ${getStatusClass(status)} ${isDragOver ? 'drag-over' : ''}`}
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      onDrop={handleDrop}
      style={{ '--column-color': color }}
    >
      <div className="column-header">
        <div className="column-title">
          <span className="column-icon">{icon}</span>
          <h2>{title}</h2>
        </div>
        <span className="column-count">{tickets.length}</span>
      </div>

      <div className="column-content">
        {tickets.length === 0 ? (
          <div className="empty-column">
            <p>No tickets</p>
            <small>Drag tickets here</small>
          </div>
        ) : (
          tickets.map((ticket) => (
            <TicketCard
              key={ticket.id}
              ticket={ticket}
              onEdit={onEditTicket}
              onDelete={onDeleteTicket}
              onRespond={onRespond}
            />
          ))
        )}
      </div>
    </div>
  );
};

export default KanbanColumn;
