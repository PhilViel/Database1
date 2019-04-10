

CREATE FUNCTION dbo.FN_CrqReplaceSpecialChar (@String VarChar(255)) RETURNS VarChar(255)
AS
BEGIN
	/* Remplace les caractères spéciaux d'une string par les mêmes caractères sans accent en minuscules */
	RETURN (
		SELECT
			REPLACE(
				REPLACE(
					REPLACE(
						REPLACE(
							REPLACE(
								REPLACE(
									REPLACE(
										REPLACE(
											REPLACE(												REPLACE(
													REPLACE(
														REPLACE(
															REPLACE(
																REPLACE(																	REPLACE(
																		REPLACE(
																			REPLACE(
																				REPLACE(
																					REPLACE(
																						LOWER(@String), 
																					CHAR(39), ''),
																				'ç', 'c'),
																			'â', 'a'),
																		'ä', 'a'),
																	'à', 'a'),
																'é', 'e'),
															'è', 'e'),
														'ë', 'e'),
													'ê', 'e'),
												'î', 'i'),
											'ì', 'i'),
										'ï', 'i'),
									'ö', 'o'),
								'ô', 'o'),
							'ò', 'o'),
						'ù', 'u'),
					'û', 'u'),
				'ü', 'u'),
			'ÿ', 'y')
		)
END

