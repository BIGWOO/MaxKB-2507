export default {
  title: 'Trigger',
  tip: 'When triggered, the system will automatically call task execution based on the input parameters settings',
  task: 'Task',
  type: {
    scheduled: 'Scheduled Trigger',
    scheduledDesc: 'Execute tasks monthly, weekly, daily, or at intervals',
    event: 'Event Trigger',
    eventDesc: 'Execute tasks when a certain event is sent',
  },
  createTrigger: 'Create Trigger',
  editTrigger: 'Edit Trigger',
  from: {
    triggerName: {
      label: 'Trigger Name',
      placeholder: 'Please enter the trigger name',
      requiredMessage: 'Please enter the trigger name',
    },
  },
}
