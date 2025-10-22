import { useState } from 'react';
import TicketCard from './TicketCard';
import './KanbanColumn.css';

/**
 * KanbanColumn - A single column in the Kanban board
 * 
 * Displays tickets for a specific status (new, in_progress, done)
 * Handles drop events to update ticket status
 */
const KanbanColumn = ({ status, title, tickets, onUpdateTicket, onEditTicket, onDeleteTicket, onRespond, icon }) => {
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
      await onUpdateTicket(parseInt(ticketId), { status });
    }
  };

  const getStatusClass = (status) => {
    switch (status) {
      case 'new':
        return 'status-new';
      case 'in_progress':
        return 'status-progress';
      case 'resolved':
      case 'done':
        return 'status-done';
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
