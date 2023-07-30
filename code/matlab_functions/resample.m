function weeklyTable = resample(dailyTable)
    % Resamples a function from daily to weekly 
    % Assuming the dates being at the index position of the OG Dataframe
    dates = datetime(dailyTable.Properties.RowNames, 'InputFormat', 'yyyy-MM-dd');

    timeTable = table2timetable(dailyTable, 'RowTimes', dates);
    timeTable = removevars(timeTable, 'Row');
    weeklyTimeTable = retime(timeTable, 'weekly', @sum);
    weeklyTable = timetable2table(weeklyTimeTable);
end

